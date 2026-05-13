use anyhow::Result;
use clap::{Parser, Subcommand};
use crossterm::style::Stylize;
use std::{
    path::PathBuf,
    process::{Command, Stdio},
};

const CLAUDE_BINARY: &str = "/data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code-linux-arm64/claude";
const INSTALLER_URL: &str = "https://raw.githubusercontent.com/DamnSit/claude-code-termux/main/install.sh";

#[derive(Parser)]
#[command(name = "claude")]
#[command(version = "1.0.0")]
#[command(about = "Claude Code Termux - Native ARM64 wrapper", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Update to latest version
    Update,
    /// Uninstall Claude Code
    Uninstall,
    /// Show version
    Version,
    /// Show this help
    Help,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Update) => update()?,
        Some(Commands::Uninstall) => uninstall()?,
        Some(Commands::Version) => version()?,
        Some(Commands::Help) => help()?,
        None => run_claude()?,
    }

    Ok(())
}

fn run_claude() -> Result<()> {
    let claude_path = PathBuf::from(CLAUDE_BINARY);
    if !claude_path.exists() {
        anyhow::bail!("Claude binary not found. Run installer first:\n  curl -fsSL {} | bash", INSTALLER_URL);
    }

    // Get all arguments except the program name
    let args: Vec<String> = std::env::args().skip(1).collect();

    // Execute grun with claude binary
    let status = Command::new("grun")
        .arg(CLAUDE_BINARY)
        .args(&args)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()?;

    std::process::exit(status.code().unwrap_or(1));
}

fn version() -> Result<()> {
    let output = Command::new("grun")
        .arg(CLAUDE_BINARY)
        .arg("--version")
        .output()?;

    print!("{}", String::from_utf8_lossy(&output.stdout));
    std::process::exit(output.status.code().unwrap_or(0));
}

fn help() -> Result<()> {
    print!(
        r#"
   ██████╗ ██████╗ ███████╗███╗   ███╗██╗
  ██╔════╝██╔═══██╗██╔════╝████╗ ████║██║
  ██║     ██║   ██║█████╗  ██╔████╔██║██║
  ██║     ██║   ██║██╔══╝  ██║╚██╔╝██║██║
  ╚██████╗╚██████╔╝███████╗██║ ╚═╝ ██║██║
   ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝

Claude Code - Usage:

  claude              Start Claude Code
  claude update       Update to latest version
  claude uninstall   Uninstall Claude Code
  claude version     Show version

"#
    );
    Ok(())
}

fn update() -> Result<()> {
    // Clear screen
    print!("\x1B[2J\x1B[1;1H");

    // Header
    println!(
        "{}",
        r#"
   ██████╗ ██████╗ ███████╗███╗   ███╗██╗
  ██╔════╝██╔═══██╗██╔════╝████╗ ████║██║
  ██║     ██║   ██║█████╗  ██╔████╔██║██║
  ██║     ██║   ██║██╔══╝  ██║╚██╔╝██║██║
  ╚██████╗╚██████╔╝███████╗██║ ╚═╝ ██║██║
   ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╚═╝"#
            .cyan()
    );

    println!("    {}  {} Termux Native", "Claude Code Updater".bold(), "•".dim());
    println!();

    // Check current version
    println!("{} Checking current version...", "▸".yellow());
    let current = get_current_version();
    println!("  └─ {}: {}", "Current".dim(), current.as_str().green());
    println!();

    // Check latest version
    println!("{} Fetching latest version info...", "▸".yellow());
    let latest = get_latest_version()?;
    println!("  └─ {}: {}", "Latest".dim(), latest.clone().green());
    println!();

    // Compare
    if current == latest {
        println!(
            "{} {}",
            "▓▒░".green(),
            "You're already on the latest version!".bold()
        );
        println!();
        println!("    {}", current.dim());
        return Ok(println!());
    }

    // Update
    println!("{} {}", "▸".yellow(), "Initiating update sequence...".bold());
    println!();

    // Progress bar
    print!("  ┌─────────────────────────────────────┐");
    print!("\r  │ ");
    for _ in 0..35 {
        print!("{}", "█".green());
        std::thread::sleep(std::time::Duration::from_millis(50));
    }
    println!(" │");
    println!("  └─────────────────────────────────────┘");
    println!();

    // Run npm update
    println!("{} Downloading packages...", "▸".yellow());
    let output = Command::new("npm")
        .args(["install", "-g", "@anthropic-ai/claude-code@latest", "@anthropic-ai/claude-code-linux-arm64@latest"])
        .output()?;

    println!("  └─ {} Packages updated", "✓".green());
    println!();

    // Verify
    println!("{} Verifying installation...", "▸".yellow());
    let new_ver = get_current_version();
    println!();

    // Success
    println!(
        "{}",
        r#"
    ╔═══════════════════════════════════════════╗
    ║                                           ║
    ║      ██████╗  █████╗ ██████╗ ██████╗      ║
    ║      ██╔══██╗██╔══██╗██╔══██╗██╔══██╗     ║
    ║      ██║  ██║███████║██████╔╝██║  ██║     ║
    ║      ██║  ██║██╔══██║██╔══██╗██║  ██║     ║
    ║      ██████╔╝██║  ██║██║  ██║██████╔╝     ║
    ║      ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝     ║
    ║                                           ║
    ╚═══════════════════════════════════════════╝"#
            .green()
    );

    println!("  {} {}", "Update Complete!".bold().white(), "\n");
    println!("  {}: {}", "Previous".dim(), current.dim());
    println!("  {}: {}", "Current".green(), new_ver.green().bold());
    println!();
    println!("  {} Type 'claude' to start coding", "claude".cyan());
    println!();

    Ok(())
}

fn uninstall() -> Result<()> {
    println!("{} Uninstalling Claude Code Termux...", "▸".yellow());

    let output = Command::new("curl")
        .args(["-fsSL", &format!("{}/uninstall.sh", INSTALLER_URL)])
        .output()?;

    if output.status.success() {
        // Write to temp file and execute
        let temp_path = "/data/data/com.termux/files/tmp/uninstall.sh";
        std::fs::write(temp_path, &output.stdout)?;
        Command::new("bash")
            .arg(temp_path)
            .status()?;
    }

    Ok(())
}

fn get_current_version() -> String {
    let output = Command::new("grun")
        .arg(CLAUDE_BINARY)
        .arg("--version")
        .output();

    match output {
        Ok(o) if o.status.success() => String::from_utf8_lossy(&o.stdout).trim().to_string(),
        _ => "unknown".to_string(),
    }
}

fn get_latest_version() -> Result<String> {
    let output = Command::new("npm")
        .args(["view", "@anthropic-ai/claude-code", "version"])
        .output()?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        Ok("unknown".to_string())
    }
}