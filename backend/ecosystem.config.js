// PM2 Ecosystem Config — MaaCare Backend
// Usage: pm2 start ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'maacare-backend',
      script: 'server.js',
      instances: 1,          // Single instance (t2.micro has 1 vCPU)
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '400M',
      env_production: {
        NODE_ENV: 'production',
        PORT: 5000,
      },
      // Auto-restart settings
      restart_delay: 3000,
      max_restarts: 10,
      min_uptime: '10s',
      // Logging
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: '/home/ubuntu/logs/maacare-error.log',
      out_file: '/home/ubuntu/logs/maacare-out.log',
      merge_logs: true,
    },
  ],
};
