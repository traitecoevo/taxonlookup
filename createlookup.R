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
  # hack until taxize fixes special character handling
  familyList$family[familyList$family=="IsoÃ«taceae"]<-"Zygophyllaceae"
  if(any(!familyList$family%in%alreadyHave)){
    suppressWarnings(tpl_get(path,family=familyList$family[!familyList$family%in%alreadyHave]))
  }
  #currently doesn't download
  #http://www.theplantlist.org/1.1/browse/P/Iso%C3%ABtaceae/Iso%C3%ABtaceae.csv
  path
}



get.genera<-function(family, path,tf){
  ah <- read.csv(file.path(path,family), stringsAsFactors=FALSE)
  accepted.species<-subset(ah,Taxonomic.status.in.TPL=="Accepted")
  group<-tf$group[match(accepted.species$Family[1],tf$family)]

  if (nrow(accepted.species)==0) {
    return(NULL)
  }

  not.species <- c("Species.hybrid.marker", "Genus.hybrid.marker", "Infraspecific.epithet")
  tmp <- accepted.species[not.species]
  accepted.species <- accepted.species[apply(tmp == "" | is.na(tmp), 1, all), ]

  if (nrow(accepted.species)==0) {
    return(NULL)
  }

  # not using table(accepted.species$Genus) because it leaves things oddly structured
  n.species <- tapply(accepted.species$Infraspecific.rank, accepted.species$Genus, length)

  out <- data.frame(family=accepted.species$Family[1],
                    genus=names(n.species),
                    group=group,
                    number.of.species=n.species,
                    stringsAsFactors=FALSE)
  return(out)
}

combineGeneraLists<-function(path,tf){
  out<-lapply(dir(path), get.genera, path,tf)
  tplGenera<-do.call(rbind,out)
  return(tplGenera)
}

matchPlantListFamiliesToApweb<-function(tplGenera){
  apFamilies<-apgFamilies()
  apFamilies$family<-gsub('"',"",apFamilies$family)
  apFamilies$order<-gsub(',',"",apFamilies$order)
  apFamilies$acceptedFamilies<-apFamilies$synonym
  apFamilies$acceptedFamilies[is.na(apFamilies$acceptedFamilies)]<-apFamilies$family[is.na(apFamilies$acceptedFamilies)]
  #tplGenera$apweb.family<-apFamilies$acceptedFamilies[match(tplGenera$family,apFamilies$acceptedFamilies)]
  #tplGenera$apweb.family[is.na(tplGenera$apweb.family)]<-apFamilies$acceptedFamilies[match(tplGenera$family,apFamilies$family)[is.na(tplGenera$apweb.family)]]
  #tplGenera$apweb.family[is.na(tplGenera$apweb.family)]<-tplGenera$family[is.na(tplGenera$apweb.family)]
  tplGenera$order<-apFamilies$order[match(tplGenera$family,apFamilies$acceptedFamilies)]
  tplGenera$order[is.na(tplGenera$order)]<-apFamilies$order[match(tplGenera$family,apFamilies$family)[is.na(tplGenera$order)]]
  return(tplGenera)
}

fixFernsAndOtherProblems<-function(genera.list, fae, errors){
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

  # tpl errors:
  ret <- dropTplErrors(genera.list, errors)

  # Sort rows and columns appropriately:
  ret <- ret[c("number.of.species","genus", "family", "order", "group")]
  ret <- ret[order(ret$group,ret$order, ret$family, ret$genus,ret$number.of.species), ]
  rownames(ret) <- NULL

  return(ret)
}

dropTplErrors <- function(genera.list, errors) {
  key <- paste(errors$genus, errors$family, sep="\r")
  i <- match(key, paste(genera.list$genus, genera.list$family, sep="\r"))
  if (any(is.na(i))) {
    msg <- errors[is.na(i)]
    mssg <- paste0("did not find errors in data:\n",
                   paste(msg$family, msg$genus, sep=" / ", collapse="\n"))
    warning(mssg, immediate.=TRUE)
    i <- i[!is.na(i)]
  }

  genera.list[-i, , drop=FALSE]
}

outputFlatFile <- function(genera.list, filename) {
  write.csv(genera.list, filename, row.names=FALSE, quote=FALSE)
}

readHigherOrderTaxonomy <- function(filename, genera.list) {
  d <- read_csv(filename)

  easy <- d[setdiff(names(d), c("X", "family"))]
  easy <- unique(easy[easy$order != "", ])

  hard <- unique(d[d$order == "", setdiff(names(d), "X")])
  i <- match(hard$family, genera.list$family)
  if (any(is.na(i))) {
    stop("higher order taxonomy needs work")
  }
  hard$order <- genera.list$order[i]
  hard <- hard[setdiff(names(hard), "family")]
  hard <- hard[!(hard$order %in% easy$order), ]
  hard <- unique(hard)

  res <- rbind(easy, hard)

  rownames(res) <- res$order
  res[names(res) != "order"]
}

packageData <- function(higher_order_taxonomy, filename) {
  save(list=c("higher_order_taxonomy"), file=filename)
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

read_csv <- function(...) {
  read.csv(..., stringsAsFactors=FALSE)
}
