args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

bs<-((i$bytes_sent))/1024/1024
br<-((i$bytes_received))/1024/1024

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(bs)),ylim=c(0,ymax=max(bs,br)*1.25),xaxs="i", yaxs="i", ylab="Network (MB)", xlab="", main="Network Traffic",las=1,xaxt="n", type="h")
lines(bs,col="purple")
lines(br,col="orange")
#par(mai=c(30,1,1,1),xpd=TRUE)
legend("top", ncol=2, legend=c("MB Sent", "MB Received"), col=c("purple","orange"), lty=1,lwd=2, bty="n")
dev.off()
