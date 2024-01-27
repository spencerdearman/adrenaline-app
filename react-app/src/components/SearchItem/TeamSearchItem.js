const SearchItem = require('./SearchItem');

export class TeamSearchItem extends SearchItem {
  constructor(team) {
    super();
    this.id = team.id;
    this.title = team.name;
    this.subtitle = 'Team';
  }
}
