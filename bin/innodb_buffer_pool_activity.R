i<-read.csv("innodb_buffer_pool_activity.csv")

mpc<-max(diff(i$pages_created))
mpr<-max(diff(i$pages_read))
mpw<-max(diff(i$pages_written))

jpeg('innodb_buffer_pool_activity.jpg')
options(scipen=20)

if (mpc > mpr && mpc>mpw) {
  plot(diff(i$pages_created), type="l", col="red", xlab="Time", main="InnoDB Buffer Pool Activity", las=1, xaxt = "n")
  lines(diff(i$pages_read), col="blue")
  lines(diff(i$pages_written), col="yellow")
  legend("top", ncol=3, legend=c("Pages Created", "Pages Read", "Pages Written"), col=c("red","blue","yellow"), lty=1,lwd=2, bty="n",)
} else if (mpr > mpw) {
  plot(diff(i$pages_read), type="l", col="red", xlab="Time", main="InnoDB Buffer Pool Activity", las=1, xaxt = "n")
  lines(diff(i$pages_created), col="blue")
  lines(diff(i$pages_written), col="yellow")
  legend("top", ncol=3, legend=c("Pages Read", "Pages Created", "Pages Written"), col=c("red","blue","yellow"), lty=1,lwd=2, bty="n",)
} else {
  plot(diff(i$pages_written), type="l", col="red", xlab="Time", main="InnoDB Buffer Pool Activity", las=1, xaxt = "n")
  lines(diff(i$pages_read), col="blue")
  lines(diff(i$pages_created), col="yellow")
  legend("top", ncol=3, legend=c("Pages Written", "Pages Read", "Pages Created"), col=c("red","blue","yellow"), lty=1,lwd=2, bty="n",)
}

dev.off()

