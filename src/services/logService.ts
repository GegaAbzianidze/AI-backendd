interface LogEntry {
  timestamp: Date;
  level: 'info' | 'warn' | 'error' | 'success';
  message: string;
}

class LogService {
  private logs: LogEntry[] = [];
  private maxLogs = 100;

  log(level: LogEntry['level'], message: string) {
    const entry: LogEntry = {
      timestamp: new Date(),
      level,
      message,
    };

    this.logs.unshift(entry); // Add to beginning
    
    // Keep only last maxLogs entries
    if (this.logs.length > this.maxLogs) {
      this.logs = this.logs.slice(0, this.maxLogs);
    }

    // Also log to console with appropriate method
    const consoleMessage = `[${level.toUpperCase()}] ${message}`;
    switch (level) {
      case 'error':
        console.error(consoleMessage);
        break;
      case 'warn':
        console.warn(consoleMessage);
        break;
      default:
        console.log(consoleMessage);
    }
  }

  info(message: string) {
    this.log('info', message);
  }

  success(message: string) {
    this.log('success', message);
  }

  warn(message: string) {
    this.log('warn', message);
  }

  error(message: string) {
    this.log('error', message);
  }

  getLogs(limit = 50): LogEntry[] {
    return this.logs.slice(0, limit);
  }

  clear() {
    this.logs = [];
  }
}

export const logger = new LogService();

