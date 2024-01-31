const SearchItem = require('./SearchItem');

export class UserSearchItem extends SearchItem {
  constructor(user) {
    super();
    this.id = user.id;
    this.title = user.firstName + ' ' + user.lastName;
    this.subtitle = 'User';
  }
}
