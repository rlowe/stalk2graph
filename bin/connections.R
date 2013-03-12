args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

df<-data.frame(
   max_connections = i$max_connections[-1],
   max_used_connections = i$max_used_connections[-1],
   aborted_clients = diff(i$aborted_clients),
   aborted_connects = diff(i$aborted_connects),
   threads_connected = i$threads_connected[-1]
)

png(filename=args[length(args)], width=800)
options(scipen=20)
plot(NULL,xlim=c(0,length(df$max_connections)),ylim=c(0,ymax=max(df)*1.25),xaxs="i", yaxs="i", ylab="Connections", xlab="", main="Connections",las=1,xaxt="n")
rect(0,0,length(df$max_connections),max(df$max_connections),col="lightgray")
lines(df$aborted_connects,col="green")
lines(df$aborted_clients,col="yellow")
lines(df$max_used_connections,col="red")
lines(df$threads_connected,col="blue")
par(mai=c(10,1,1,1),xpd=TRUE)
legend("bottom", ncol=3, legend=c("Max Connections", "Aborted Connets", "Aborted Clients", "Max Used Connections", "Threads Connected"), col=c("lightgray","green","yellow","red","blue"), lty=1,lwd=2, bty="n")
dev.off()
