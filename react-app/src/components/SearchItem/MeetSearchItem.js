const SearchItem = require('./SearchItem');

export class MeetSearchItem extends SearchItem {
  constructor(meet) {
    super();
    this.id = meet.id;
    this.title = meet.name;
    this.subtitle = 'Meet';
  }
}
