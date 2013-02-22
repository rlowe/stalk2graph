args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

png(args[length(args)],width=800)
options(scipen=20)
plot(diff(i$merges), type="l", col="red", xlab="Time", main="InnoDB Insert Buffer", las=1, xaxt = "n")
lines(diff(i$free_list), col="blue")
lines(diff(i$merged_delete_marks), col="yellow")
lines(diff(i$merged_deletes), col="purple")
lines(diff(i$merged_inserts), col="orange")
legend("top", ncol=5, legend=c("Merges", "Merged Delete Marks","Merged Deletes","Merged Inserts"), col=c("red","blue"), lty=1,lwd=2, bty="n",)
dev.off()

