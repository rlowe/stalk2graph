args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

df<-data.frame(
   cache_size = i$cache_size[-1],
   threads_created = diff(i$threads_created),
   threads_cached = i$threads_cached[-1]
)

png(filename=args[length(args)], width=800)
options(scipen=20)
plot(NULL,xlim=c(0,length(df$cache_size)),ylim=c(0,ymax=max(df)*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main="Threads",las=1,xaxt="n")
rect(0,0,length(df$cache_size),max(df$cache_size),col="lightgray")
lines(df$threads_cached,col="green")
lines(df$threads_created,col="red")
par(mai=c(10,1,1,1),xpd=TRUE)
legend("bottom", ncol=3, legend=c("Cache Size", "Threads Cached", "Threads Created"), col=c("lightgray","green","red"), lty=1,lwd=2, bty="n")
dev.off()
