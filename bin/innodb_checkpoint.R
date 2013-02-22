args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)])

ma<-max(diff(i$target_age))
ta<-max(diff(i$max_age))

jpeg('innodb_checkpoint.jpg')
options(scipen=20)

if (ma>ta) {
  plot(i$max_age, type="l", col="red", xlab="Time", main="InnoDB Checkpoint", las=1, xaxt = "n")
  lines(i$target_age, col="blue")
  lines(i$age, col="purple")
  legend("top", ncol=3, legend=c("Max Age", "Target Age", "Age"), col=c("red","blue","yellow"), lty=1,lwd=2, bty="n",)
} else {
  plot(i$target_age, type="l", col="red", xlab="Time", main="InnoDB Checkpoint", las=1, xaxt = "n")
  lines(i$max_age, col="blue")
  lines(i$age, col="purple")
  legend("top", ncol=3, legend=c("Target Age", "Max Age", "Age"), col=c("red","blue","yellow"), lty=1,lwd=2, bty="n",)
}

dev.off()

