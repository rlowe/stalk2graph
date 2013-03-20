args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(i$Total)),ylim=c(0,ymax=max(i$Total)*1.25),xaxs="i", yaxs="i", ylab="Memory (kB)", xlab="", main="Linux Memory",las=1,xaxt="n")
rect(0,0,length(i$Total),max(i$Total),col="lightgray")
lines(i$Free,col="green")
lines(i$Cached,col="yellow")
lines(i$SwapCached,col="red")
par(mai=c(10,1,1,1),xpd=TRUE)
legend("bottom", ncol=4, legend=c("Total", "Free", "Cached", "SwapCached"), col=c("lightgray","green","yellow","red"), lty=1,lwd=2, bty="n")
dev.off()
