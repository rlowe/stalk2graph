args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

fr<-max((i$file_reads))
fw<-max((i$file_writes))
lw<-max((i$log_writes))
fs<-max((i$file_syncs))

png(args[length(args)],width=800)
options(scipen=20)

if (fr > fw && fr > lw && fr > fs) {
  plot((i$file_reads), type="l", col="red", ylab="", xlab="", main="InnoDB I/O", las=1, xaxt = "n")
  lines((i$file_writes), col="blue")
  lines((i$log_writes), col="orange")
  lines((i$file_syncs), col="purple")
  legend("top", ncol=4, legend=c("File Reads", "File Writes", "Log Writes", "File Syncs"), col=c("red","blue","orange","purple"), lty=1,lwd=2, bty="n")
} else if (fw > lw && fw > fs) {
  plot((i$file_writes), type="l", col="red", ylab="", xlab="", main="InnoDB I/O", las=1, xaxt = "n")
  lines((i$file_reads), col="blue")
  lines((i$log_writes), col="orange")
  lines((i$file_syncs), col="purple")
  legend("top", ncol=4, legend=c("File Writes", "File Reads", "Log Writes", "File Syncs"), col=c("red","blue","orange","purple"), lty=1,lwd=2, bty="n")
} else if (lw > fs) {
  plot((i$log_writes), type="l", col="red", ylab="", xlab="", main="InnoDB I/O", las=1, xaxt = "n")
  lines((i$file_writes), col="blue")
  lines((i$file_reads), col="orange")
  lines((i$file_syncs), col="purple")
  legend("top", ncol=4, legend=c("Log Writes", "File Writes", "File Reads", "File Syncs"), col=c("red","blue","orange","purple"), lty=1,lwd=2, bty="n")
} else {
  plot((i$file_syncs), type="l", col="red", ylab="", xlab="", main="InnoDB I/O", las=1, xaxt = "n")
  lines((i$file_writes), col="blue")
  lines((i$log_writes), col="orange")
  lines((i$file_reads), col="purple")
  legend("top", ncol=4, legend=c("File Syncs", "File Writes", "Log Writes", "File Reads"), col=c("red","blue","orange","purple"), lty=1,lwd=2, bty="n")
}

dev.off()

