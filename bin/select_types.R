require(ggplot2)

select_types_data<-read.csv("select_types.csv")

sfj<-diff(select_types_data$full_join)
sfrj<-diff(select_types_data$full_range_join)
sr<-diff(select_types_data$range)
src<-diff(select_types_data$range_check)
ss<-diff(select_types_data$scan)

select_types_data<-data.frame(Time="", Type="", Value=as.numeric(""))
select_types_data<-select_types_data[-1,]

for (i in 1:length(hw)) {
    select_types_data<-rbind( select_types_data,
                                  data.frame(Time=as.character(i),
                                             Type="Full Join",
                                             Value=as.numeric(sfj[i])))
    select_types_data<-rbind( select_types_data,
                                  data.frame(Time=as.character(i),
                                             Type="Full Range Join",
                                             Value=as.numeric(sfrj[i])))
    select_types_data<-rbind( select_types_data,
                                  data.frame(Time=as.character(i),
                                             Type="Range",
                                             Value=as.numeric(sr[i])))
    select_types_data<-rbind( select_types_data,
                                  data.frame(Time=as.character(i),
                                             Type="Range Check",
                                             Value=as.numeric(src[i])))
    select_types_data<-rbind( select_types_data,
                                  data.frame(Time=as.character(i),
                                             Type="Scan",
                                             Value=as.numeric(ss[i])))
}

jpeg('select_types.jpg')
ggplot(select_types_data, aes(x=Time, y=Value, fill=Type, color=Type, group=Type, xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle("MySQL Select Types")
dev.off()

