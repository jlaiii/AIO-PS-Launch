# All-in-One Tool Launcher

This is a simple PowerShell script launcher designed to manage and run various tools from a central location. It checks for local copies of scripts and, if they are not found, downloads them from the internet.

## Getting Started

### Prerequisites

* Windows operating system
* PowerShell 5.1 or later

### How to Run

1.  **Clone this repository** or download the files.
2.  **Edit `scripts.txt`** to add or remove the tools you want to use. The format is `Nickname|URL|LocalFileName.ps1`.
3.  **Run `Launcher.bat`** to start the tool. This batch file automatically finds and executes the PowerShell script with the correct execution policy.

## Customization

You can easily customize this tool by editing the `scripts.txt` file.

**Example `scripts.txt`:**

```
# AIO Tool Launcher Configuration
# Add your scripts below in the format: Nickname|URL|LocalFileName
# Use the '#' character for comments.

Windows Toolbox|[https://christitus.com/win](https://christitus.com/win)|win-toolbox.ps1
Activated.win|[https://get.activated.win](https://get.activated.win)|activated-win.ps1
Another Tool|[https://example.com/script.ps1](https://example.com/script.ps1)|my-script.ps1
```

## How It Works

* `Launcher.bat`: A simple batch file that sets the execution policy and runs `Launcher.ps1`.
* `Launcher.ps1`: The core PowerShell script that reads the configuration from `scripts.txt`, presents a menu to the user, and either runs a local script or downloads it before execution.
* `scripts.txt`: A plain text file that acts as the configuration for your tool list.
