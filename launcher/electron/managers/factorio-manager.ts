// Factorio process and installation management module
import { exec, ChildProcess } from "child_process";
import { promisify } from "util";
import { join } from "path";
import { existsSync, readFileSync } from "fs";

const execAsync = promisify(exec);

export interface FactorioStatus {
  status: 'running' | 'stopped';
  error: boolean;
}

export interface LaunchResult {
  success: boolean;
  message: string;
}

export class FactorioManager {
  private statusCheckInterval: NodeJS.Timeout | null = null;
  private onStatusChange?: (status: FactorioStatus) => void;

  constructor(onStatusChange?: (status: FactorioStatus) => void) {
    this.onStatusChange = onStatusChange;
  }

  // Find Factorio executable from registry and Steam libraries
  public async findFactorioExecutable(): Promise<string[]> {
    const possiblePaths: string[] = [];
    
    try {
      // Try to find from registry (Steam installation)
      const { stdout } = await execAsync('reg query "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Steam App 427520" /v "InstallLocation" /reg:64');
      const match = stdout.match(/InstallLocation\s+REG_SZ\s+(.+)/);
      if (match && match[1]) {
        const steamPath = match[1].trim();
        const exePath = join(steamPath, "bin", "x64", "factorio.exe");
        if (existsSync(exePath)) {
          possiblePaths.push(exePath);
        }
      }
    } catch (error) {
      console.log("Failed to find Factorio from registry");
    }

    try {
      // Try to find Steam libraries
      const steamPath = await this.getSteamPath();
      if (steamPath) {
        const libraryFoldersPath = join(steamPath, "steamapps", "libraryfolders.vdf");
        if (existsSync(libraryFoldersPath)) {
          const vdfContent = readFileSync(libraryFoldersPath, 'utf8');
          const libraryFolders = this.parseVDF(vdfContent);
          
          // Extract library paths from VDF content
          for (const key in libraryFolders.libraryfolders) {
            if (libraryFolders.libraryfolders[key].path) {
              const libraryPath = libraryFolders.libraryfolders[key].path;
              const factorioPath = join(libraryPath, "steamapps", "common", "Factorio", "bin", "x64", "factorio.exe");
              if (existsSync(factorioPath)) {
                possiblePaths.push(factorioPath);
              }
            }
          }
        }
      }
    } catch (error) {
      console.log("Failed to find Factorio from Steam libraries:", error);
    }

    return possiblePaths;
  }

  // Get Steam installation path from registry
  private async getSteamPath(): Promise<string | null> {
    try {
      const { stdout } = await execAsync('reg query "HKEY_LOCAL_MACHINE\\SOFTWARE\\Valve\\Steam" /v "InstallPath" /reg:64');
      const match = stdout.match(/InstallPath\s+REG_SZ\s+(.+)/);
      if (match && match[1]) {
        return match[1].trim();
      }
    } catch (error) {
      console.log("Failed to find Steam path from registry");
    }
    return null;
  }

  // Simple VDF parser for Steam library folders
  private parseVDF(vdfContent: string): any {
    const result: any = { libraryfolders: {} };
    const lines = vdfContent.split('\n');
    let currentSection = '';
    let currentObj: any = {};

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('//')) continue;

      // Check for section start
      const sectionMatch = trimmed.match(/^"([^"]+)"\s*$/);
      if (sectionMatch) {
        currentSection = sectionMatch[1];
        continue;
      }

      // Check for key-value pair
      const kvMatch = trimmed.match(/^"([^"]+)"\s+"([^"]+)"$/);
      if (kvMatch) {
        const [_, key, value] = kvMatch;
        
        if (currentSection === 'libraryfolders') {
          // Library folder entries are numbered (e.g., "0", "1", etc.)
          if (!isNaN(Number(key))) {
            result.libraryfolders[key] = result.libraryfolders[key] || {};
            currentObj = result.libraryfolders[key];
          } else if (currentObj) {
            // Add property to current library folder object
            currentObj[key] = value;
          }
        }
      }
    }

    return result;
  }

  // Check if Factorio is running using tasklist command
  public async isFactorioRunning(): Promise<boolean> {
    try {
      const { stdout } = await execAsync('tasklist /fi "imagename eq factorio.exe" /fo csv /nh');
      // If Factorio is running, the output will include "factorio.exe"
      return stdout.toLowerCase().includes('factorio.exe');
    } catch (error) {
      console.error('Error checking if Factorio is running:', error);
      return false;
    }
  }

  // Start monitoring Factorio status and notify about changes
  public startStatusMonitoring(): void {
    // Clear any existing interval
    this.stopStatusMonitoring();
    
    // Check immediately
    this.checkAndNotifyStatus();
    
    // Then check periodically
    this.statusCheckInterval = setInterval(() => {
      this.checkAndNotifyStatus();
    }, 5000);
  }

  // Stop monitoring Factorio status
  public stopStatusMonitoring(): void {
    if (this.statusCheckInterval) {
      clearInterval(this.statusCheckInterval);
      this.statusCheckInterval = null;
    }
  }

  // Check if Factorio is running and notify about changes
  private async checkAndNotifyStatus(): Promise<void> {
    if (!this.onStatusChange) return;
    
    const running = await this.isFactorioRunning();
    
    // Send status update
    this.onStatusChange({ 
      status: running ? 'running' : 'stopped',
      error: false
    });
  }

  // Launch Factorio with the specified path and UDP port
  public async launchFactorio(factorioPath: string, udpPort: number): Promise<LaunchResult> {
    // First check if Factorio is already running
    const running = await this.isFactorioRunning();
    if (running) {
      return { success: false, message: "Factorio is already running" };
    }
    
    if (factorioPath && existsSync(factorioPath)) {
      try {
        // Launch the process with UDP port arguments
        exec(`"${factorioPath}" --enable-lua-udp ${udpPort}`);
        
        // Give it 2 seconds to start, then check status
        setTimeout(async () => {
          await this.checkAndNotifyStatus();
        }, 2000);
        
        return { success: true, message: `Factorio launch initiated with UDP port ${udpPort}` };
      } catch (error) {
        return { success: false, message: `Failed to launch Factorio: ${error.message}` };
      }
    }
    return { success: false, message: "Factorio executable not found" };
  }
}
