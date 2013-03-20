args<-commandArgs(trailingOnly = FALSE)
i<-read.csv(args[length(args)-1])

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(i$tmp_tables)),ylim=c(0,ymax=max(diff(i$tmp_tables),diff(i$tmp_disk_tables))*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main="Temporary Tables",las=1,xaxt="n", type="h")
lines(diff(i$tmp_tables),col="purple")
lines(diff(i$tmp_disk_tables),col="orange")
legend("top", ncol=2, legend=c("Temp Tables", "Temp Disk Tables"), col=c("purple","orange"), lty=1,lwd=2, bty="n")
dev.off()
