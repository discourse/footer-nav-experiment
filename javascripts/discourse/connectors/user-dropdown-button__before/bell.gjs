import Component from "@glimmer/component";
import dIcon from "discourse-common/helpers/d-icon";

export default class bellIcon extends Component {
  <template>
    <button class="btn btn-transparent icon no-text">
      {{dIcon "bell"}}
    </button>
  </template>
}
