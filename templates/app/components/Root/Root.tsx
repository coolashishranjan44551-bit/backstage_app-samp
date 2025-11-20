import React from 'react';
import { Sidebar, SidebarItem, SidebarPage, SidebarDivider, SidebarSpace, SidebarGroup } from '@backstage/core-components';
import { SidebarLogo } from '@backstage/core-components';
import { SidebarSearch } from '@backstage/plugin-search';
import HomeIcon from '@material-ui/icons/Home';
import LibraryBooks from '@material-ui/icons/LibraryBooks';
import Create from '@material-ui/icons/Create';
import ViewList from '@material-ui/icons/ViewList';
import Docs from '@material-ui/icons/Description';
import Pipeline from '@material-ui/icons/Timeline';
import CloudQueue from '@material-ui/icons/CloudQueue';
import Dashboard from '@material-ui/icons/Dashboard';

export const Root = ({ children }: { children?: React.ReactNode }) => (
  <SidebarPage>
    <Sidebar>
      <SidebarLogo />
      <SidebarSearch />
      <SidebarDivider />
      <SidebarItem icon={HomeIcon} to="/" text="Home" />
      <SidebarItem icon={ViewList} to="/catalog" text="Catalog" />
      <SidebarItem icon={Create} to="/create" text="Create" />
      <SidebarItem icon={Docs} to="/docs" text="Docs" />
      <SidebarItem icon={Pipeline} to="/azure-pipelines" text="Pipelines" />
      <SidebarItem icon={Dashboard} to="/grafana" text="Grafana" />
      <SidebarItem icon={CloudQueue} to="/kubernetes" text="Kubernetes" />
      <SidebarGroup label="More">
        <SidebarItem icon={LibraryBooks} to="/catalog-import" text="Import" />
      </SidebarGroup>
      <SidebarSpace />
    </Sidebar>
    {children}
  </SidebarPage>
);
