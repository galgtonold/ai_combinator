import ipc from "../utils/ipc";
import { config, configService } from "./config-store";
import { statusService } from "./status-store";
import { get } from 'svelte/store';
import { MIN_LAUNCH_DURATION, getErrorMessage } from "@shared";

/**
 * Factorio management service
 */
export class FactorioService {
  /**
   * Browse for Factorio executable
   */
  async browseFactorioPath(): Promise<void> {
    const path = await ipc.browseFactorioPath();
    if (path) {
      configService.updateConfig({ factorioPath: path });
      const currentConfig = get(config);
      await configService.saveConfig(currentConfig);
      this.updateFactorioStatus();
      statusService.setStatus("Factorio executable selected successfully", "success");
    }
  }

  /**
   * Auto-detect Factorio installation
   */
  async autoDetectFactorio(): Promise<void> {
    const path = await ipc.autoDetectFactorio();
    if (path) {
      configService.updateConfig({ factorioPath: path });
      const currentConfig = get(config);
      await configService.saveConfig(currentConfig);
      this.updateFactorioStatus();
      statusService.setStatus("Factorio executable detected automatically", "success");
    } else {
      statusService.setStatus("Failed to detect Factorio executable", "error");
    }
  }

  /**
   * Launch Factorio
   */
  async launchFactorio(): Promise<void> {
    const currentConfig = get(config);
    
    // Prevent launching if already running
    // We'll need to get this from the status store, but for now let's check via IPC
    const isRunning = await ipc.isFactorioRunning();
    if (isRunning) {
      statusService.setStatus("Factorio is already running", "error");
      return;
    }

    if (!currentConfig.factorioPath) {
      statusService.setStatus("Factorio executable not found", "error");
      return;
    }

    statusService.setLaunching(true);
    statusService.setStatus("Launching Factorio...", "success");

    // Record the start time to ensure minimum launch duration
    const launchStartTime = Date.now();

    try {
      const result = await ipc.launchFactorio();
      if (result.success) {
        statusService.setStatus(result.message, "success");
        statusService.setWasRunning(true); // Set wasRunning to true when we successfully launch Factorio
      } else {
        statusService.setStatus(result.message, "error");
      }
    } catch (error) {
      statusService.setStatus(`Error launching Factorio: ${getErrorMessage(error)}`, "error");
    } finally {
      // Ensure the launching state is shown for at least MIN_LAUNCH_DURATION
      const elapsedTime = Date.now() - launchStartTime;
      const remainingTime = Math.max(0, MIN_LAUNCH_DURATION - elapsedTime);
      
      if (remainingTime > 0) {
        setTimeout(() => {
          statusService.setLaunching(false);
        }, remainingTime);
      } else {
        statusService.setLaunching(false);
      }
    }
  }

  /**
   * Update Factorio status based on configuration
   */
  updateFactorioStatus(): void {
    const currentConfig = get(config);
    if (currentConfig.factorioPath) {
      // Check current status to avoid overriding "running" status
      // For now, we'll just set to "found" if not running
      statusService.setFactorioStatus("found");
    } else {
      statusService.setFactorioStatus("not_found");
    }
  }

  /**
   * Check if Factorio is currently running
   */
  async checkFactorioStatus(): Promise<void> {
    const isRunning = await ipc.isFactorioRunning();
    const currentConfig = get(config);
    
    if (isRunning) {
      statusService.setFactorioStatus("running");
      statusService.setWasRunning(true);
    } else if (currentConfig.factorioPath) {
      statusService.setFactorioStatus("found");
    } else {
      statusService.setFactorioStatus("not_found");
    }
  }
}

// Create and export a singleton instance
export const factorioService = new FactorioService();
