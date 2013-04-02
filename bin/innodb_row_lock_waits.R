args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(i$waits)),ylim=c(0,ymax=max(diff(i$waits))*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main="InnoDB Row Lock Waits",las=1,xaxt="n", type="h")
lines(diff(i$waits),col="red")
legend("top", ncol=1, legend=c("Waits"), col=c("red"), lty=1,lwd=2, bty="n")
dev.off()
