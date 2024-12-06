import Component from "@glimmer/component";
import { service } from "@ember/service";
import dIcon from "discourse-common/helpers/d-icon";

export default class bellIcon extends Component {
  @service site;
  <template>
    {{#if this.site.mobileView}}
      {{dIcon "bell"}}
    {{/if}}
  </template>
}
