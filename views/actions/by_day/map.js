function(doc) {
  if(doc.type == "action"){
    date = new Date(doc.closed_at);
    current = new Date();
    year = date.getFullYear();
    month = date.getMonth() + 1;
    day = date.getDate();
    emit([doc.user, year, month, day], 1)
  }
}
