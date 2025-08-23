import { writable } from 'svelte/store';
import type { FactorioStatus } from "../utils/ipc";

export type StatusType = "error" | "warning" | "success";

export interface StatusState {
  factorioStatus: FactorioStatus;
  factorioStatusText: string;
  factorioStatusClass: StatusType;
  statusMessage: string;
  isLaunching: boolean;
  wasRunning: boolean;
}

// Create reactive status store
const initialStatus: StatusState = {
  factorioStatus: "not_found",
  factorioStatusText: "Not found",
  factorioStatusClass: "error",
  statusMessage: "",
  isLaunching: false,
  wasRunning: false,
};

export const status = writable<StatusState>(initialStatus);

/**
 * Status service for managing application status and messages
 */
export class StatusService {
  /**
   * Update Factorio status
   */
  setFactorioStatus(factorioStatus: FactorioStatus): void {
    status.update(current => {
      const newStatus = { ...current, factorioStatus };
      if (factorioStatus === "running") {
        newStatus.wasRunning = true;
      }
      this.updateFactorioStatusDisplay(newStatus);
      return newStatus;
    });
  }

  /**
   * Set launching state
   */
  setLaunching(isLaunching: boolean): void {
    status.update(current => ({ ...current, isLaunching }));
  }

  /**
   * Set was running state
   */
  setWasRunning(wasRunning: boolean): void {
    status.update(current => ({ ...current, wasRunning }));
  }

  /**
   * Update the factorio status display based on current status
   */
  private updateFactorioStatusDisplay(statusValue: StatusState): void {
    // If there's an active status message, don't update the factorioStatusText
    if (statusValue.statusMessage) return;

    switch (statusValue.factorioStatus) {
      case "not_found":
        statusValue.factorioStatusText = "Not found";
        statusValue.factorioStatusClass = "error";
        break;
      case "found":
        statusValue.factorioStatusText = "Found";
        statusValue.factorioStatusClass = "success";
        break;
      case "running":
        statusValue.factorioStatusText = "Running";
        statusValue.factorioStatusClass = "success";
        break;
      case "stopped":
        statusValue.factorioStatusText = "Stopped";
        statusValue.factorioStatusClass = "warning";
        break;
    }
  }

  /**
   * Set a temporary status message that will clear after a timeout
   */
  setStatus(message: string, type: StatusType, timeout: number = 5000): void {
    status.update(current => ({
      ...current,
      statusMessage: message,
      factorioStatusClass: type // Temporarily override the status class
    }));

    // After the timeout, clear the status message and restore the original factorio status display
    setTimeout(() => {
      status.update(current => {
        const newStatus = { ...current, statusMessage: "" };
        this.updateFactorioStatusDisplay(newStatus);
        return newStatus;
      });
    }, timeout);
  }

  /**
   * Clear the current status message
   */
  clearStatus(): void {
    status.update(current => {
      const newStatus = { ...current, statusMessage: "" };
      this.updateFactorioStatusDisplay(newStatus);
      return newStatus;
    });
  }
}

// Create and export a singleton instance
export const statusService = new StatusService();
