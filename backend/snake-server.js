require('dotenv').config();
const express = require('express');
const crypto = require('crypto');
const fetch = require('node-fetch');
const cron = require('node-cron');

// Configuration
const PORT = process.env.PORT || 3004;
const PINKHAT_SERVER_URL = process.env.PINKHAT_SERVER_URL || 'http://localhost:3002';
const PINKHAT_ADMIN_KEY = process.env.PINKHAT_ADMIN_KEY;
const CLIENT_KEY = process.env.CLIENT_KEY;

const MAX_TIMESTAMP_AGE = 60;                           // Maximum age of submission in seconds

// Reward distribution config
const REWARD_CRON_SCHEDULE = process.env.REWARD_CRON_SCHEDULE || '0 */6 * * *';  // Every 6 hours by default
const REWARD_TOP_COUNT = parseInt(process.env.REWARD_TOP_COUNT) || 10;           // Top 10 players
const REWARD_AUTO_DISTRIBUTE = process.env.REWARD_AUTO_DISTRIBUTE !== 'false';   // Enable by default


// Parse cron schedule to determine interval in milliseconds
function getCronIntervalMillis(cronSchedule) {
    const parts = cronSchedule.trim().split(/\s+/);
    if (parts.length < 5) return 6 * 60 * 60 * 1000; // Default to 6 hours if invalid

    const minutePart = parts[0];
    const hourPart = parts[1];

    // Pattern: */N * * * * (every N minutes)
    if (minutePart.startsWith('*/')) {
        const minutes = parseInt(minutePart.substring(2));
        return minutes * 60 * 1000;
    }

    // Pattern: N */H * * * (every H hours)
    if (hourPart.startsWith('*/')) {
        const hours = parseInt(hourPart.substring(2));
        return hours * 60 * 60 * 1000;
    }

    // Pattern: N H * * * (daily at specific time) = 24 hours
    if (!hourPart.includes('*') && !hourPart.includes('/')) {
        return 24 * 60 * 60 * 1000;
    }

    // Default to 6 hours for complex patterns
    return 6 * 60 * 60 * 1000;
}


/**
 * Calculate reward interval from cron schedule
 */
const REWARD_INTERVAL_MILLIS = getCronIntervalMillis(REWARD_CRON_SCHEDULE);
const REWARD_INTERVAL_HOURS = REWARD_INTERVAL_MILLIS / (60 * 60 * 1000);


/**
 * Calculate when the previous cron period started (start time of current competition period)
 */
function getPreviousCronTime(cronSchedule) {
    const now = Date.now();
    const intervalMillis = getCronIntervalMillis(cronSchedule);
    const elapsed = now % intervalMillis;
    return new Date(now - elapsed);
}


/**
 * Calculate when the next cron will run (end time of current competition)
 */
function getNextCronTime(cronSchedule) {
    const now = Date.now();
    const intervalMillis = getCronIntervalMillis(cronSchedule);
    const elapsed = now % intervalMillis;
    const remaining = intervalMillis - elapsed;
    return new Date(now + remaining);
}


/**
 * Hours since the previous cron period started
 */
function getHoursSincePreviousCron(cronSchedule) {
    const now = Date.now();
    const intervalMillis = getCronIntervalMillis(cronSchedule);
    const elapsed = now % intervalMillis;
    return elapsed / (60 * 60 * 1000);
}


const app = express();
app.use(express.json({ limit: '1mb' }));

// CORS middleware
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    next();
});

// Logging middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
});


/**
 * Create hash from score, metadata (as JSON string), and timestamp.
 * Used to validate that the score was submitted within the last minute and the metadata wasn't directly tampered with.
 */
function createHash(score, metadata, timestamp) {
    const metadataJson = JSON.stringify(metadata);
    const data = `${score}|${metadataJson}|${CLIENT_KEY}|${timestamp}`;
    return crypto.createHash('sha256').update(data).digest('hex');
}


/**
 * Runs before score submission to verify that the score is valid.
 * Must return { valid: false } if the submission should be deemed invalid.
 */
function validateGameData(score, metadata) {
    // No metadata validation is implemented here, as it should be proprietary and game-specific.
    //
    // Custom metadata JSON can be sent during score submission and parsed here,
    // to check for suspicious or impossible values that don't add up.
    // 
    // For actual tournaments, it is recommended to log submitted metadata for later review.

    return { valid: true };
}


/**
 * POST /game/submit-score
 * Validates and submits a game score to the pinkhat backend
 * Accepts flexible metadata structure for custom validation implemented in validateGameData()
 */
app.post('/game/submit-score', async (req, res) => {
    try {
        const { address, score, metadata, hash, timestamp } = req.body;

        // Validate required fields
        if (!address || score === undefined || !metadata || !hash || !timestamp) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: address, score, metadata, hash, timestamp'
            });
        }

        // Validate metadata is an object
        if (typeof metadata !== 'object' || Array.isArray(metadata)) {
            return res.status(400).json({
                success: false,
                message: 'Metadata must be a valid JSON object'
            });
        }

        // Validate timestamp is recent
        const now = Math.floor(Date.now() / 1000);
        const timeDiff = Math.abs(now - timestamp);
        if (timeDiff > MAX_TIMESTAMP_AGE) {
            return res.status(400).json({
                success: false,
                message: `Submission too old or timestamp in future (${timeDiff}s difference, max: ${MAX_TIMESTAMP_AGE}s)`
            });
        }

        // Verify hash (anti-tamper check)
        const expectedHash = createHash(score, metadata, timestamp);

        if (hash !== expectedHash) {
            return res.status(400).json({
                success: false,
                message: 'Invalid hash - data verification failed'
            });
        }

        // Custom validation in validateGameData()
        const validation = validateGameData(score, metadata);
        if (!validation.valid) {
            return res.status(400).json({
                success: false,
                message: validation.reason || 'Invalid submission'
            });
        }

        // Submit to pinkhat backend
        if (!PINKHAT_ADMIN_KEY) {
            return res.status(500).json({
                success: false,
                message: 'Server configuration error'
            });
        }

        const pinkhatResponse = await fetch(`${PINKHAT_SERVER_URL}/admin/submit-game`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-API-Key': PINKHAT_ADMIN_KEY
            },
            body: JSON.stringify({
                players: [address],
                scores: [score]
            })
        });

        const pinkhatData = await pinkhatResponse.json();

        if (pinkhatResponse.ok && pinkhatData.success) {
            return res.json({
                success: true,
                gameId: pinkhatData.gameId,
                transactionHash: pinkhatData.transactionHash,
                message: 'Score submitted successfully'
            });
        } else {
            return res.status(500).json({
                success: false,
                message: pinkhatData.message || pinkhatData.error || 'Failed to submit to blockchain'
            });
        }

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});


/**
 * Distribute rewards to top players
 * Fetches leaderboard and distributes rewards: 1.0, 0.9, 0.8, ..., 0.1 ETH
 */
async function distributeRewards() {
    try {
        console.log('\n========================================');
        console.log('Starting Reward Distribution');
        console.log('========================================');

        if (!PINKHAT_ADMIN_KEY) {
            console.log('ERROR - Cannot distribute rewards: PINKHAT_ADMIN_KEY not configured');
            return;
        }

        // Calculate exact cutoff time based on cron schedule (start of previous period)
        const currentPeriodStart = getPreviousCronTime(REWARD_CRON_SCHEDULE);
        const cutoffTime = new Date(currentPeriodStart.getTime() - REWARD_INTERVAL_MILLIS);
        const periodEnd = currentPeriodStart; // End of previous period = start of current period

        const queryHours = Math.ceil(REWARD_INTERVAL_HOURS);

        // Fetch top scores from pinkhat backend
        console.log(`   Fetching top ${REWARD_TOP_COUNT} scores from previous period...`);
        console.log(`   Period: ${cutoffTime.toISOString()} to ${periodEnd.toISOString()}`);
        console.log(`   Duration: ${REWARD_INTERVAL_HOURS} hours`);
        console.log(`   Query hours: ${queryHours}`);

        const leaderboardUrl = `${PINKHAT_SERVER_URL}/leaderboard/top-scores?limit=${REWARD_TOP_COUNT}&hours=${queryHours}&mode=players`;
        const leaderboardResponse = await fetch(leaderboardUrl);

        if (!leaderboardResponse.ok) {
            console.log('ERROR - Failed to fetch leaderboard:', leaderboardResponse.statusText);
            return;
        }

        const leaderboardData = await leaderboardResponse.json();
        let results = leaderboardData.results || [];

        // Filter results to only include scores within our exact time period
        // This ensures we only include scores from the previous period
        const unfilteredCount = results.length;
        results = results.filter(result => {
            const createdAt = new Date(result.lastGameTime.endsWith('Z') ? result.lastGameTime : result.lastGameTime + 'Z' );
            return createdAt >= cutoffTime && createdAt < periodEnd;
        });

        if (unfilteredCount !== results.length) {
            console.log(`   Filtered out ${unfilteredCount - results.length} score(s) outside period window; original results: ${JSON.stringify(leaderboardData.results)}`);
        }

        if (results.length === 0) {
            console.log('No scores found in the time period. Skipping reward distribution.');
            console.log('========================================\n');
            return;
        }

        console.log(`Found ${results.length} player(s) eligible for rewards`);

        // Calculate rewards
        const winners = [];
        const amounts = [];

        for (let i = 0; i < results.length; i++) {
            const player = results[i];
            const rewardEth = 1.0 - (i * 0.1);

            if (rewardEth <= 0) break;  // Stop when reward would be 0 or negative

            winners.push(player.address);
            // Convert ETH to wei
            const rewardWei = (rewardEth * 1e18).toString();
            amounts.push(rewardWei);

            console.log(`   #${i + 1}: ${player.address.substring(0, 10)}... - ${rewardEth.toFixed(1)} ETH (Score: ${player.bestScore})`);
        }

        if (winners.length === 0) {
            console.log('No valid winners to reward.');
            console.log('========================================\n');
            return;
        }

        // Distribute rewards via pinkhat backend
        console.log(`\nDistributing rewards to ${winners.length} winner(s)...`);

        const distributeResponse = await fetch(`${PINKHAT_SERVER_URL}/admin/distribute-leaderboard-rewards`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-API-Key': PINKHAT_ADMIN_KEY
            },
            body: JSON.stringify({
                winners: winners,
                amounts: amounts,
                description: `Snake Game - Top ${winners.length} rewards (period: ${cutoffTime.toISOString()} - ${periodEnd.toISOString()})`
            })
        });

        const distributeData = await distributeResponse.json();

        if (distributeResponse.ok && distributeData.success) {
            console.log('Rewards distributed successfully!');
            console.log(`   Transaction: ${distributeData.transactionHash}`);
            console.log(`   Block: ${distributeData.blockNumber}`);
            console.log(`   Total distributed: ${(parseFloat(distributeData.totalDistributed) / 1e18).toFixed(1)} ETH`);
        } else {
            console.log('Reward distribution failed:', distributeData.message || distributeData.error);
        }

        console.log('========================================\n');

    } catch (error) {
        console.error('Error during reward distribution:', error.message);
        console.log('========================================\n');
    }
}


/**
 * GET /game/current-period-leaderboard
 * Proxy endpoint to fetch leaderboard for the current competition period
 * Returns top scores since the last reward distribution
 */
app.get('/game/current-period-leaderboard', async (req, res) => {
    try {
        // Calculate exact period boundaries based on cron schedule
        const cutoffTime = getPreviousCronTime(REWARD_CRON_SCHEDULE);
        const nextCronTime = getNextCronTime(REWARD_CRON_SCHEDULE);
        const hoursSinceCutoff = getHoursSincePreviousCron(REWARD_CRON_SCHEDULE);

        // Get limit from query params or use default
        const limit = Math.min(parseInt(req.query.limit) || REWARD_TOP_COUNT, 100);

        // Round up hours to ensure we don't miss any scores
        // (pinkhat backend accepts the number of hours as an integer)
        const queryHours = Math.ceil(hoursSinceCutoff);

        // Fetch from pinkhat backend
        const leaderboardUrl = `${PINKHAT_SERVER_URL}/leaderboard/top-scores?limit=${limit}&hours=${queryHours}&mode=players`;
        const leaderboardResponse = await fetch(leaderboardUrl);

        if (!leaderboardResponse.ok) {
            return res.status(500).json({
                success: false,
                message: 'Failed to fetch leaderboard from pinkhat backend'
            });
        }

        const leaderboardData = await leaderboardResponse.json();
        let results = leaderboardData.results || [];

        // Filter results to only include scores within our exact time period
        const unfilteredCount = results.length;
        results = results.filter(result => {
            const createdAt = new Date(result.lastGameTime.endsWith('Z') ? result.lastGameTime : result.lastGameTime + 'Z' );
            return createdAt >= cutoffTime;
        });

        if (unfilteredCount !== results.length) {
            console.log(`   Filtered out ${unfilteredCount - results.length} score(s) older than cutoff time; original results: ${JSON.stringify(leaderboardData.results)}`);
        }

        // Update leaderboard data with filtered results
        leaderboardData.results = results;

        // Add period info to response
        return res.json({
            success: true,
            periodInfo: {
                periodStart: cutoffTime.toISOString(),
                nextReward: nextCronTime.toISOString(),
                hoursSincePeriodStart: parseFloat(hoursSinceCutoff.toFixed(2)),
                intervalHours: REWARD_INTERVAL_HOURS
            },
            leaderboard: leaderboardData
        });

    } catch (error) {
        console.error('❌ Error fetching current period leaderboard:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});


/**
 * GET /
 * Health check and API info
 */
app.get('/', (req, res) => {
    const previousCron = getPreviousCronTime(REWARD_CRON_SCHEDULE);
    const nextCron = getNextCronTime(REWARD_CRON_SCHEDULE);

    res.json({
        status: 'OK',
        service: 'Snek Score Server',
        version: '69.42.0'
    });
});


// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Endpoint not found'
    });
});


// Error handler
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).json({
        error: 'Internal server error',
        message: error.message
    });
});


// Start server
app.listen(PORT, () => {
    console.log('========================================');
    console.log('Turbo Snek Score Server');
    console.log('========================================');
    console.log(`Server: http://localhost:${PORT}`);
    console.log(`Pinkhat: ${PINKHAT_SERVER_URL}`);
    console.log('========================================');
    console.log('========================================');
    console.log('Reward Distribution:');
    console.log(`   Auto-distribute: ${REWARD_AUTO_DISTRIBUTE ? 'Enabled' : 'Disabled'}`);
    console.log(`   Schedule: ${REWARD_CRON_SCHEDULE}`);
    console.log(`   Interval: ${REWARD_INTERVAL_HOURS} hours`);
    console.log(`   Top ${REWARD_TOP_COUNT} players rewarded per period`);
    console.log(`   Reward amounts: 1.0, 0.9, 0.8, ... ETH`);
    console.log('========================================\n');

    if (!PINKHAT_ADMIN_KEY) {
        console.log('WARNING: PINKHAT_ADMIN_KEY not set!');
        console.log('Score submissions will fail until configured.\n');
    }

    // Set up cron job for reward distribution
    if (REWARD_AUTO_DISTRIBUTE) {
        if (!PINKHAT_ADMIN_KEY) {
            console.log('WARNING: Reward auto-distribution is enabled but PINKHAT_ADMIN_KEY is not set!');
            console.log('Rewards will not be distributed until admin key is configured.\n');
        } else {
            console.log(`Starting reward distribution cron job (${REWARD_CRON_SCHEDULE})\n`);

            cron.schedule(REWARD_CRON_SCHEDULE, () => {
                console.log(`\nCron triggered at ${new Date().toISOString()}`);
                distributeRewards();
            });
        }
    } else {
        console.log('Reward auto-distribution is disabled (set REWARD_AUTO_DISTRIBUTE=true to enable)\n');
    }
});

module.exports = app;