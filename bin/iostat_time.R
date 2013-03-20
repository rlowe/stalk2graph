args<-commandArgs(trailingOnly = FALSE)

require(ggplot2)

c<-read.csv(args[length(args)-1])

qt<-c$queue
st<-c$service

d<-data.frame(Time="", Command="", Value=as.numeric(""))
d<-d[-1,]

for (i in 1:length(qt)) {
    d<-rbind( d,
              data.frame(Time=as.character(i),
                         Command="Queue Time",
                         Value=qt[i]))
    d<-rbind( d,
              data.frame(Time=as.character(i),
                         Command='Service Time',
                         Value=st[i]))
}

png(filename=args[length(args)],width=800)
options(scipen=20)
ggplot(d, aes(x=Time, y=Value, fill=Command, color=Command, group=Command, xlab="",ylab="",xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle(paste(args[length(args)-2], "I/O")) + theme(axis.title.y = element_blank(), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks = element_blank(), panel.grid.major = element_blank(),panel.grid.minor=element_blank())
dev.off()

