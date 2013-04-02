args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

df<-data.frame(
   max_age = i$max_age,
   target_age = i$target_age,
   age = i$age
)

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(df$max_age)),ylim=c(0,ymax=max(df)*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main="InnoDB Checkpoint Age",las=1,xaxt="n")
rect(0,0,length(df$max_age),max(df$max_age),col="lightgray")
lines(df$target_age,col="black")
lines(df$age,col="red")
par(mai=c(10,1,1,1),xpd=TRUE)
legend("bottom", ncol=3, legend=c("Max Age", "Target Age", "Age"), col=c("lightgray","black","red"), lty=1,lwd=2, bty="n")
dev.off()
