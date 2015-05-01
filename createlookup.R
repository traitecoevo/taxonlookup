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
  ah <- read.csv(file.path(path,family), stringsAsFactors=FALSE)
  out <- data.frame(family=ah$Family[1], genus=unique(ah$Genus),
                    stringsAsFactors=FALSE)
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

fixFernsAndOtherProblems<-function(genera.list, fae){
  problems<-unique(genera.list$family[is.na(genera.list$order)])
  genera.list$family[genera.list$family=="Dryopteridacae"]<-"Dryopteridaceae" # spelling mistake in the plant list
  genera.list$order[is.na(genera.list$order)]<-fae$order[match(genera.list$family,fae$family)[is.na(genera.list$order)]]
  genera.list$order[genera.list$family=="Cystodiaceae"]<-"Polypodiales"
  genera.list$family[genera.list$family=="Isoëtaceae"]<-"Isoetaceae"
  genera.list$order[genera.list$family=="Isoetaceae"]<-"Isoetales"

  # Rename some families with modern names
  genera.list$family[genera.list$family == "Leguminosae"] <- "Fabaceae"
  genera.list$family[genera.list$family == "Compositae"] <- "Asteraceae"

  # Too many spaces:
  genera.list$order <- gsub("\\s\\s+", " ", genera.list$order)
  # Other standardisation:
  genera.list$order <- title_case(genera.list$order)

  # Sort rows and columns appropriately:
  ret <- genera.list[c("genus", "family", "order")]
  ret <- ret[order(ret$order, ret$family, ret$genus), ]
  rownames(ret) <- NULL

  return(ret)
}

outputFlatFile<-function(genera.list){
  write.csv(genera.list, "genusFamilyOrder.csv", row.names=FALSE, quote=FALSE)
}

packageData <- function(object, filename) {
  name <- tools::file_path_sans_ext(basename(filename))
  assign(name, object)
  save(list=name, file=filename)
}

title_case <- function(x) {
  re <- "(.*)\\b([a-z])(.*)"
  i <- grepl(re, x)
  if (any(i)) {
    x[i] <- paste0(sub(re, "\\1", x[i]),
                   toupper(sub(re, "\\2", x[i])),
                   sub(re, "\\3", x[i]))
    title_case(x)
  }
  x
}
