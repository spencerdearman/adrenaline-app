const SearchItem = require('./SearchItem');

export class CollegeSearchItem extends SearchItem {
  constructor(college) {
    super();
    this.id = college.id;
    this.title = college.name;
    this.subtitle = 'College';
  }
}
