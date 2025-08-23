import type { FactorioStatus } from "../utils/ipc";

export type StatusType = "error" | "warning" | "success";

/**
 * Status store for managing application status and messages
 */
export class StatusStore {
  private _factorioStatus: FactorioStatus = $state("not_found");
  private _factorioStatusText: string = $state("Not found");
  private _factorioStatusClass: StatusType = $state("error");
  private _statusMessage: string = $state("");
  private _isLaunching: boolean = $state(false);
  private _wasRunning: boolean = $state(false);

  get factorioStatus(): FactorioStatus {
    return this._factorioStatus;
  }

  get factorioStatusText(): string {
    return this._factorioStatusText;
  }

  get factorioStatusClass(): StatusType {
    return this._factorioStatusClass;
  }

  get statusMessage(): string {
    return this._statusMessage;
  }

  get isLaunching(): boolean {
    return this._isLaunching;
  }

  get wasRunning(): boolean {
    return this._wasRunning;
  }

  /**
   * Update Factorio status
   */
  setFactorioStatus(status: FactorioStatus): void {
    this._factorioStatus = status;
    if (status === "running") {
      this._wasRunning = true;
    }
    this.updateFactorioStatusDisplay();
  }

  /**
   * Set launching state
   */
  setLaunching(isLaunching: boolean): void {
    this._isLaunching = isLaunching;
  }

  /**
   * Set was running state
   */
  setWasRunning(wasRunning: boolean): void {
    this._wasRunning = wasRunning;
  }

  /**
   * Update the factorio status display based on current status
   */
  updateFactorioStatusDisplay(): void {
    // If there's an active status message, don't update the factorioStatusText
    if (this._statusMessage) return;

    switch (this._factorioStatus) {
      case "not_found":
        this._factorioStatusText = "Not found";
        this._factorioStatusClass = "error";
        break;
      case "found":
        this._factorioStatusText = "Found";
        this._factorioStatusClass = "success";
        break;
      case "running":
        this._factorioStatusText = "Running";
        this._factorioStatusClass = "success";
        break;
      case "stopped":
        this._factorioStatusText = "Stopped";
        this._factorioStatusClass = "warning";
        break;
    }
  }

  /**
   * Set a temporary status message that will clear after a timeout
   */
  setStatus(message: string, type: StatusType, timeout: number = 5000): void {
    this._statusMessage = message;
    // Temporarily override the status class to show the message type
    this._factorioStatusClass = type;

    // After the timeout, clear the status message and restore the original factorio status display
    setTimeout(() => {
      this._statusMessage = "";
      this.updateFactorioStatusDisplay();
    }, timeout);
  }

  /**
   * Clear the current status message
   */
  clearStatus(): void {
    this._statusMessage = "";
    this.updateFactorioStatusDisplay();
  }
}

// Create and export a singleton instance
export const statusStore = new StatusStore();
