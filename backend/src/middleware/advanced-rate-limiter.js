const { RateLimiterRedis } = require('rate-limiter-flexible');
const redisClientService = require('../services/redis-client.service');

const rateLimiterIP = new RateLimiterRedis({
	storeClient: () => redisClientService.getClient(),
	keyPrefix: 'rl_ip',
	points: 10,
	duration: 900,
	blockDuration: 3600,
});

const rateLimiterEmail = new RateLimiterRedis({
	storeClient: () => redisClientService.getClient(),
	keyPrefix: 'rl_email',
	points: 5,
	duration: 900,
	blockDuration: 7200,
});

const rateLimiterProgressive = new RateLimiterRedis({
	storeClient: () => redisClientService.getClient(),
	keyPrefix: 'rl_progressive',
	points: 1,
	duration: 1,
	blockDuration: 1,
	execEvenly: true,
});

const advancedRateLimit = async (req, res, next) => {
	const ip = req.ip;
	const email = req.body?.email?.toLowerCase();
	try {
		// Always enforce IP limiter
		await rateLimiterIP.consume(ip);
		// If email present, also enforce email and combined progressive limiter
		if (email) {
			await rateLimiterEmail.consume(email);
			await rateLimiterProgressive.consume(`${ip}:${email}`);
		}
		return next();
	} catch (rejRes) {
		const ms = rejRes?.msBeforeNext || 1000;
		const secs = Math.max(1, Math.round(ms / 1000));
		res.set('Retry-After', String(secs));
		return res.status(429).json({
			success: false,
			code: 'TOO_MANY_REQUESTS',
			message: `Too many login attempts. Try again in ${secs} seconds.`,
			retryAfter: secs,
		});
	}
};

module.exports = { advancedRateLimit };


