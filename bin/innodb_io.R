args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

fr<-max(diff(i$file_reads))
fw<-max(diff(i$file_writes))
lw<-max(diff(i$log_writes))
fs<-max(diff(i$file_syncs))

png(args[length(args)],width=800)
options(scipen=20)

if (fr > fw && fr > lw && fr > fs) {
  plot(diff(i$file_reads), type="l", col="red", xlab="Time", main="InnoDB I/O", las=1, xaxt = "n")
  lines(diff(i$file_writes), col="blue")
  lines(diff(i$log_writes), col="yellow")
  lines(diff(i$file_syncs), col="purple")
  legend("top", ncol=4, legend=c("File Reads", "File Writes", "Log Writes", "File Syncs"), col=c("red","blue","yellow","purple"), lty=1,lwd=2, bty="n")
} else if (fw > lw && fw > fs) {
  plot(diff(i$file_writes), type="l", col="red", xlab="Time", main="InnoDB I/O", las=1, xaxt = "n")
  lines(diff(i$file_reads), col="blue")
  lines(diff(i$log_writes), col="yellow")
  lines(diff(i$file_syncs), col="purple")
  legend("top", ncol=4, legend=c("File Writes", "File Reads", "Log Writes", "File Syncs"), col=c("red","blue","yellow","purple"), lty=1,lwd=2, bty="n")
} else if (lw > fs) {
  plot(diff(i$log_writes), type="l", col="red", xlab="Time", main="InnoDB I/O", las=1, xaxt = "n")
  lines(diff(i$file_writes), col="blue")
  lines(diff(i$file_reads), col="yellow")
  lines(diff(i$file_syncs), col="purple")
  legend("top", ncol=4, legend=c("Log Writes", "File Writes", "File Reads", "File Syncs"), col=c("red","blue","yellow","purple"), lty=1,lwd=2, bty="n")
} else {
  plot(diff(i$file_syncs), type="l", col="red", xlab="Time", main="InnoDB I/O", las=1, xaxt = "n")
  lines(diff(i$file_writes), col="blue")
  lines(diff(i$log_writes), col="yellow")
  lines(diff(i$file_reads), col="purple")
  legend("top", ncol=4, legend=c("File Syncs", "File Writes", "Log Writes", "File Reads"), col=c("red","blue","yellow","purple"), lty=1,lwd=2, bty="n")
}

plot(diff(i$hash_searches), type="l", col="red", xlab="Time", ylab="Searches", main="InnoDB Adaptive Hash Searches", las=1, xaxt = "n")
lines(diff(i$non_hash_searches), col="blue")
legend("top", ncol=2, legend=c("Hash Searches", "Non-Hash Searches"), col=c("red","blue"), lty=1,lwd=2, bty="n",)
dev.off()

