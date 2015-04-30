# library(devtools)
# install_github("ropensci/taxize")
# install_github("richfitz/remake")
# require(taxize)
# require(remake)

getTplVascularPlantFamilies<-function(){
  #get full list of families
  tf<-tpl_families()
  #exclude bryophytes
  tf<-subset(tf,tf$group!="Bryophytes")
  return(tf)
}

downloadPlantList<-function(familyList){
  path <- "plantListAcceptedNames"
  dir.create(path, FALSE)
  alreadyHaveFile<-dir(path)
  alreadyHave<-sub(".csv","",alreadyHaveFile)
  suppressWarnings(tpl_get(path,family=familyList$family[!familyList$family%in%alreadyHave]))
  path
}

get.genera<-function(family, path){
  ah<-read.csv(file.path(path,family))
  out<-data.frame(family=ah$Family[1],genus=unique(ah$Genus))
  return(out)
}

combineGeneraLists<-function(path){
  out<-lapply(dir(path), get.genera, path)
  tplGenera<-do.call(rbind,out)
  return(tplGenera)
}

matchPlantListFamiliesToApweb<-function(tplGenera){
  apFamilies<-apgFamilies()
  apFamilies$family<-gsub('"',"",apFamilies$family)
  apFamilies$order<-gsub(',',"",apFamilies$order)
  apFamilies$acceptedFamilies<-apFamilies$synonym
  apFamilies$acceptedFamilies[is.na(apFamilies$acceptedFamilies)]<-apFamilies$family[is.na(apFamilies$acceptedFamilies)]
  tplGenera$order<-apFamilies$order[match(tplGenera$family,apFamilies$acceptedFamilies)]
  tplGenera$order[is.na(tplGenera$order)]<-apFamilies$order[match(tplGenera$family,apFamilies$family)[is.na(tplGenera$order)]]
  return(tplGenera)
}

fixFernsAndOtherProblems<-function(genera.list){
  problems<-unique(genera.list$family[is.na(genera.list$order)])
  genera.list$family[genera.list$family=="Dryopteridacae"]<-"Dryopteridaceae" # spelling mistake in the plant list
  fae<-read.csv(file ="inst/extdata//genus_order_lookup_fae.csv",stringsAsFactors=F)
  genera.list$order[is.na(genera.list$order)]<-fae$order[match(genera.list$family,fae$family)[is.na(genera.list$order)]]
  genera.list$order[genera.list$family=="Cystodiaceae"]<-"Polypodiales"
  genera.list$order[genera.list$family=="Isoëtaceae"]<-"Isoetaceae"
  genera.list$order[genera.list$family=="Isoetaceae"]<-"Isoetales"
  return(genera.list)
}

outputFlatFile<-function(genera.list){
  out<-data.frame(genus=genera.list$genus,family=genera.list$family,order=genera.list$order)
  write.csv(out,"genusFamilyOrder.csv",row.names=F,quote=FALSE)
}
