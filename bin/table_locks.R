args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

tli<-(diff(i$immediate))
tlw<-(diff(i$waited))

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(tlw)),ylim=c(0,ymax=max(tli,tlw)*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main="Table Locks",las=1,xaxt="n", type="h")
lines(tli,col="purple")
lines(tlw,col="orange")
legend("top", ncol=2, legend=c("Locks Immediate", "Locks Waited"), col=c("purple","orange"), lty=1,lwd=2, bty="n")
dev.off()
