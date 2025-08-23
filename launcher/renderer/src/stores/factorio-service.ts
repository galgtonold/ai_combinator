import ipc from "../utils/ipc";
import { configStore } from "./config-store";
import { statusStore } from "./status-store";

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
      configStore.updateConfig({ factorioPath: path });
      await configStore.saveConfig();
      this.updateFactorioStatus();
      statusStore.setStatus("Factorio executable selected successfully", "success");
    }
  }

  /**
   * Auto-detect Factorio installation
   */
  async autoDetectFactorio(): Promise<void> {
    const path = await ipc.autoDetectFactorio();
    if (path) {
      configStore.updateConfig({ factorioPath: path });
      await configStore.saveConfig();
      this.updateFactorioStatus();
      statusStore.setStatus("Factorio executable detected automatically", "success");
    } else {
      statusStore.setStatus("Failed to detect Factorio executable", "error");
    }
  }

  /**
   * Launch Factorio
   */
  async launchFactorio(): Promise<void> {
    // Prevent launching if already running
    if (statusStore.factorioStatus === "running") {
      statusStore.setStatus("Factorio is already running", "error");
      return;
    }

    if (!configStore.config.factorioPath) {
      statusStore.setStatus("Factorio executable not found", "error");
      return;
    }

    statusStore.setLaunching(true);
    statusStore.setStatus("Launching Factorio...", "success");

    // Record the start time to ensure minimum 5 second duration
    const launchStartTime = Date.now();
    const minLaunchDuration = 5000; // 5 seconds in milliseconds

    try {
      const result = await ipc.launchFactorio();
      if (result.success) {
        statusStore.setStatus(result.message, "success");
        statusStore.setWasRunning(true); // Set wasRunning to true when we successfully launch Factorio
      } else {
        statusStore.setStatus(result.message, "error");
      }
    } catch (error) {
      statusStore.setStatus(`Error launching Factorio: ${error}`, "error");
    } finally {
      // Ensure the launching state is shown for at least 5 seconds
      const elapsedTime = Date.now() - launchStartTime;
      const remainingTime = Math.max(0, minLaunchDuration - elapsedTime);
      
      if (remainingTime > 0) {
        setTimeout(() => {
          statusStore.setLaunching(false);
        }, remainingTime);
      } else {
        statusStore.setLaunching(false);
      }
    }
  }

  /**
   * Update Factorio status based on configuration
   */
  updateFactorioStatus(): void {
    if (configStore.config.factorioPath) {
      if (statusStore.factorioStatus !== "running") {
        statusStore.setFactorioStatus("found");
      }
    } else {
      statusStore.setFactorioStatus("not_found");
    }
  }

  /**
   * Check if Factorio is currently running
   */
  async checkFactorioStatus(): Promise<void> {
    const isRunning = await ipc.isFactorioRunning();
    if (isRunning) {
      statusStore.setFactorioStatus("running");
      statusStore.setWasRunning(true);
    } else if (configStore.config.factorioPath) {
      statusStore.setFactorioStatus("found");
    } else {
      statusStore.setFactorioStatus("not_found");
    }
  }
}

// Create and export a singleton instance
export const factorioService = new FactorioService();
