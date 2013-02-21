i<-read.csv("innodb_adaptive_hash_searches.csv")

jpeg('innodb_adaptive_hash_searches.jpg')
options(scipen=20)
plot(diff(i$hash_searches), type="l", col="red", xlab="Time", ylab="Searches", main="InnoDB Adaptive Hash Searches", las=1, xaxt = "n")
lines(diff(i$non_hash_searches), col="blue")
legend("top", ncol=2, legend=c("Hash Searches", "Non-Hash Searches"), col=c("red","blue"), lty=1,lwd=2, bty="n",)
dev.off()

