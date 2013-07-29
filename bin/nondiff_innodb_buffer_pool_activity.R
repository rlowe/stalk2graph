args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

mpc<-max((i$pages_created))
mpr<-max((i$pages_read))
mpw<-max((i$pages_written))

png(args[length(args)],width=800)
options(scipen=20)

if (mpc > mpr && mpc>mpw) {
  plot((i$pages_created), type="l", col="red", xlab="Time", main="InnoDB Buffer Pool Activity", las=1, xaxt = "n")
  lines((i$pages_read), col="blue")
  lines((i$pages_written), col="orange")
  legend("top", ncol=3, legend=c("Pages Created", "Pages Read", "Pages Written"), col=c("red","blue","orange"), lty=1,lwd=2, bty="n",)
} else if (mpr > mpw) {
  plot((i$pages_read), type="l", col="red", xlab="Time", main="InnoDB Buffer Pool Activity", las=1, xaxt = "n")
  lines((i$pages_created), col="blue")
  lines((i$pages_written), col="orange")
  legend("top", ncol=3, legend=c("Pages Read", "Pages Created", "Pages Written"), col=c("red","blue","orange"), lty=1,lwd=2, bty="n",)
} else {
  plot((i$pages_written), type="l", col="red", xlab="Time", main="InnoDB Buffer Pool Activity", las=1, xaxt = "n")
  lines((i$pages_read), col="blue")
  lines((i$pages_created), col="orange")
  legend("top", ncol=3, legend=c("Pages Written", "Pages Read", "Pages Created"), col=c("red","blue","orange"), lty=1,lwd=2, bty="n",)
}

dev.off()

