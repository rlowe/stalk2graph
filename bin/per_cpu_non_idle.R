args<-commandArgs(trailingOnly = FALSE)
c<-read.csv(args[length(args)-1])

png(filename=args[length(args)], width=800)
options(scipen=20)

plot(NULL,xlim=c(0,length(c$CPU0)),ylim=c(0,ymax=max(c,na.rm=TRUE)*1.25),xaxs="i", yaxs="i", ylab="", xlab="", main="Per-CPU Busy Time",las=1,xaxt="n",type="h")

l=NULL
lcol=NULL

for (i in 0:(length(c)-2)) {
  l<-c(l,(paste0("CPU",as.character(i))))
  if (i == 0) { 
    lines(c$CPU0,col="black")
    lcol<-c(lcol,"black")
  }
  if (i == 1) { 
    lines(c$CPU1,col="brown")
    lcol<-c(lcol,"brown")
  }
  if (i == 2) { 
    lines(c$CPU2,col="red")
    lcol<-c(lcol,"red")
  }
  if (i == 3) { 
    lines(c$CPU3,col="orange")
    lcol<-c(lcol,"orange")
  }
  if (i == 4) { 
    lines(c$CPU4,col="yellow")
    lcol<-c(lcol,"yellow")
  }
  if (i == 5) { 
    lines(c$CPU5,col="green")
    lcol<-c(lcol,"green")
  }
  if (i == 6) { 
    lines(c$CPU6,col="blue")
    lcol<-c(lcol,"blue")
  }
  if (i == 7) { 
    lines(c$CPU7,col="purple")
    lcol<-c(lcol,"purple")
  }
  
}

legend("top", ncol=4, legend=l, col=lcol, lty=1,lwd=2, bty="n")

dev.off()
