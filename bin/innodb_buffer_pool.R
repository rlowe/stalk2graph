args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

# Convert this to GB
i<-round((i*16)/1024/1024)

png(args[length(args)],width=800)
options(scipen=20)
plot(i$pool_size,type="l",col="red",xlab="Time",ylab="Size (GB)",main="InnoDB Buffer Pool", las=1,xaxt="n")
lines(i$database_pages, col="blue")
lines(i$pages_free, col="orange")
lines(i$modified_pages, col="purple")
legend("top", ncol=4, legend=c("Pool Size", "Database Pages", "Free Pages", "Modified Pages"), col=c("red","blue","orange","purple"), lty=1,lwd=2, bty="n",)
dev.off()

