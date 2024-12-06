import Component from "@glimmer/component";
import { service } from "@ember/service";
import dIcon from "discourse-common/helpers/d-icon";
import DMenu from "float-kit/components/d-menu";
import DropdownMenu from "discourse/components/dropdown-menu";
import DButton from "discourse/components/d-button";
import avatar from "discourse/helpers/avatar";
import UserStatusMenu from "discourse/components/header/user-dropdown/user-status-bubble";
import UserMenuProfileTabContent from "discourse/components/user-menu/profile-tab-content";

export default class userMenu extends Component {
  @service currentUser;
  <template>
    <DMenu
      @modalForMobile={{true}}
      @class="btn-transparent d-header__user-menu"
    >
      <:trigger>
        {{avatar this.currentUser imageSize="small"}}
      </:trigger>

      <:content>
        <UserMenuProfileTabContent />
      </:content>
    </DMenu>
  </template>
}
