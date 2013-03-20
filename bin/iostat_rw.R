args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(i$r)),ylim=c(0,ymax=max(i)*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main=paste(args[length(args)-2], "R/W"),las=1,xaxt="n", type="h")
lines(i$r,col="purple")
lines(i$w,col="orange")
legend("top", ncol=2, legend=c("Reads", "Writes"), col=c("purple","orange"), lty=1,lwd=2, bty="n")
dev.off()
