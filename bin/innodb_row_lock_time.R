args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(i$time)),ylim=c(0,ymax=max(diff(i$time))*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main="InnoDB Row Lock Time (MS)",las=1,xaxt="n", type="h")
lines(diff(i$time),col="red")
legend("top", ncol=1, legend=c("time"), col=c("red"), lty=1,lwd=2, bty="n")
dev.off()
