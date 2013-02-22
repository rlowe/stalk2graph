args<-commandArgs(trailingOnly = FALSE)

require(ggplot2)

sorts_data<-read.csv(args[length(args)-1])

smp<-diff(sorts_data$merge_passes)
srange<-diff(sorts_data$range)
srows<-diff(sorts_data$rows)
ss<-diff(sorts_data$scan)

sorts_data<-data.frame(Time="", Type="", Value=as.numeric(""))
sorts_data<-sorts_data[-1,]

for (i in 1:length(ss)) {
    sorts_data<-rbind( sorts_data,
                                  data.frame(Time=as.character(i),
                                             Type="Merge Passes",
                                             Value=as.numeric(smp[i])))
    sorts_data<-rbind( sorts_data,
                                  data.frame(Time=as.character(i),
                                             Type="Range",
                                             Value=as.numeric(srange[i])))
    sorts_data<-rbind( sorts_data,
                                  data.frame(Time=as.character(i),
                                             Type="Rows",
                                             Value=as.numeric(srows[i])))
    sorts_data<-rbind( sorts_data,
                                  data.frame(Time=as.character(i),
                                             Type="Scan",
                                             Value=as.numeric(ss[i])))
}

png(args[length(args)],width=800)
ggplot(sorts_data, aes(x=Time, y=Value, fill=Type, color=Type, group=Type, xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle("MySQL Sorts")
dev.off()

