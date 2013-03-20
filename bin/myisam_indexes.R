args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

rr<-diff(i$read_requests)
r<-diff(i$reads)
wr<-diff(i$write_requests)
w<-diff(i$writes)

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(w)),ylim=c(0,ymax=max(r,w,rr,wr)*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main="MyISAM Indexes",las=1,xaxt="n", type="h")
lines(rr,col="green")
lines(r,col="dark green")
lines(wr,col="red")
lines(w,col="orange")

legend("top", ncol=4, legend=c("Read Requests", "Reads", "Write Requests", "Writes"), col=c("green","dark green","red","orange"), lty=1,lwd=2, bty="n")
dev.off()
