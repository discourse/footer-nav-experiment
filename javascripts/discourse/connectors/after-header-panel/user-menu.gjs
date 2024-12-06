import Component from "@glimmer/component";
import { service } from "@ember/service";
import UserStatusMenu from "discourse/components/header/user-dropdown/user-status-bubble";
import UserMenuProfileTabContent from "discourse/components/user-menu/profile-tab-content";
import avatar from "discourse/helpers/avatar";
import DMenu from "float-kit/components/d-menu";

export default class userMenu extends Component {
  @service currentUser;
  @service site;

  <template>
    {{#if this.site.mobileView}}
      <DMenu
        @modalForMobile={{true}}
        @class="btn-transparent d-header__user-menu"
      >
        <:trigger>
          {{avatar this.currentUser imageSize="small"}}
          <UserStatusMenu
            @timezone={{this.this.currentUser.user_option.timezone}}
            @status={{this.currentUser.status}}
          />
        </:trigger>

        <:content>
          <UserMenuProfileTabContent />
        </:content>
      </DMenu>
    {{/if}}
  </template>
}
