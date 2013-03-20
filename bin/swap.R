args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

si<-i$si
so<-i$so

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(si)),ylim=c(0,ymax=max(si,so)*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main="Swap",las=1,xaxt="n", type="h")
lines(so,col="purple")
lines(si,col="orange")

legend("top", ncol=2, legend=c("Swap Out", "Swap In"), col=c("purple","orange"), lty=1,lwd=2, bty="n")
dev.off()
