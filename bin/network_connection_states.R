args<-commandArgs(trailingOnly = FALSE)

require(ggplot2)

ns<-read.csv(args[length(args)-1])

ss<-ns$send_syn
sr<-ns$syn_received
e<-ns$established
l<-ns$listen
fw1<-ns$fin_wait_1
tw<-ns$time_wait
cw<-ns$close_wait
fw2<-ns$fin_wait_2
la<-ns$last_ack
c<-ns$closed

n<-data.frame(Time="", State="", Value=as.numeric(""))
n<-n[-1,]

for (i in 1:length(c)) {
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="SEND_SYN",
                         Value=ss[i]))
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="SYN_RECEIVED",
                         Value=sr[i]))
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="ESTABLISHED",
                         Value=e[i]))
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="LISTEN",
                         Value=l[i]))
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="FIN_WAIT_1",
                         Value=fw1[i]))
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="TIME_WAIT",
                         Value=tw[i]))
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="CLOSE_WAIT",
                         Value=cw[i]))
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="FIN_WAIT_2",
                         Value=fw2[i]))
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="LAST_ACK",
                         Value=la[i]))
    n<-rbind( n,
              data.frame(Time=as.character(i),
                         State="CLOSED",
                         Value=c[i]))
}

png(filename=args[length(args)],width=800)
options(scipen=20)
ggplot(n, aes(x=Time, y=Value, fill=State, color=State, group=State, xlab="",ylab="",xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle("Network Connection States") + theme(axis.title.y = element_blank(), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks = element_blank(), panel.grid.major = element_blank(),panel.grid.minor=element_blank())
dev.off()

