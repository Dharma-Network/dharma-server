function(doc) {
  if(doc.type == "action") {
    emit(doc.user, doc.dharma)
  }
}
