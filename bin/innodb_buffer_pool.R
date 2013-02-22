args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)])

# Convert this to GB
i<-round((i*16)/1024/1024)

jpeg('innodb_buffer_pool.jpg')
options(scipen=20)
plot(i$pool_size,type="l",col="red",xlab="Time",ylab="Size (GB)",main="InnoDB Buffer Pool", las=1,xaxt="n")
lines(i$database_pages, col="blue")
lines(i$pages_free, col="yellow")
lines(i$modified_pages, col="purple")
legend("top", ncol=4, legend=c("Pool Size", "Database Pages", "Free Pages", "Modified Pages"), col=c("red","blue","yellow","purple"), lty=1,lwd=2, bty="n",)
dev.off()

