import React from 'react';
import { Route } from 'react-router';
import { FlatRoutes } from '@backstage/core-app-api';
import { AlertDisplay, OAuthRequestDialog } from '@backstage/core-components';
import { createApp } from '@backstage/app-defaults';
import { apis } from './apis';
import { Root } from './components/Root';
import { SignInPage } from '@backstage/core-components';
import { HomePage } from '@backstage/plugin-home';
import { CatalogIndexPage, CatalogEntityPage } from '@backstage/plugin-catalog';
import { CatalogImportPage } from '@backstage/plugin-catalog-import';
import { ScaffolderPage, ScaffolderFieldExtensions } from '@backstage/plugin-scaffolder';
import { ApiExplorerPage } from '@backstage/plugin-api-docs';
import { TechDocsIndexPage, TechDocsReaderPage } from '@backstage/plugin-techdocs';
import { EntityLayout } from '@backstage/plugin-catalog';
import { EntityAboutCard } from '@backstage/plugin-catalog';
import { EntityApiDefinitionCard } from '@backstage/plugin-api-docs';
import { EntityTechdocsContent } from '@backstage/plugin-techdocs';
import { EntityGithubActionsContent } from '@backstage/plugin-github-actions';
import { AzurePipelinesPage } from '@backstage/plugin-azure-devops';
import { GrafanaPage } from '@backstage/plugin-grafana';
import { KubernetesPage, EntityKubernetesContent } from '@backstage/plugin-kubernetes';
import { Router as DocsRouter } from '@backstage/plugin-techdocs';
import { apiDocsPlugin } from '@backstage/plugin-api-docs';
import { catalogPlugin } from '@backstage/plugin-catalog';
import { scaffolderPlugin } from '@backstage/plugin-scaffolder';
import { techdocsPlugin } from '@backstage/plugin-techdocs';

const app = createApp({
  apis,
  bindRoutes({ bind }) {
    bind(catalogPlugin.externalRoutes, {
      createComponent: scaffolderPlugin.routes.root,
      viewTechDoc: techdocsPlugin.routes.docRoot,
    });
    bind(apiDocsPlugin.externalRoutes, {
      createComponent: scaffolderPlugin.routes.root,
    });
    bind(scaffolderPlugin.externalRoutes, {
      viewTechDoc: techdocsPlugin.routes.docRoot,
    });
  },
  components: {
    SignInPage: props => (
      <SignInPage {...props} auto providers={['guest', 'github', 'microsoft']} />
    ),
  },
});

const AppProvider = app.getProvider();
const AppRouter = app.getRouter();

export default app.createRoot(
  <AppProvider>
    <AlertDisplay />
    <OAuthRequestDialog />
    <Root>
      <AppRouter>
        <FlatRoutes>
          <Route path="/" element={<HomePage />} />
          <Route path="/catalog" element={<CatalogIndexPage />} />
          <Route path="/catalog/:namespace/:kind/:name" element={<CatalogEntityPage />}>            
            <EntityLayout>
              <EntityLayout.Route path="overview" title="Overview">
                <EntityAboutCard variant="gridItem" />
              </EntityLayout.Route>
              <EntityLayout.Route path="ci-cd" title="CI/CD">
                <EntityGithubActionsContent />
              </EntityLayout.Route>
              <EntityLayout.Route path="kubernetes" title="Kubernetes">
                <EntityKubernetesContent refreshIntervalMs={30000} />
              </EntityLayout.Route>
              <EntityLayout.Route path="docs" title="Docs">
                <EntityTechdocsContent />
              </EntityLayout.Route>
              <EntityLayout.Route path="api" title="API">
                <EntityApiDefinitionCard />
              </EntityLayout.Route>
            </EntityLayout>
          </Route>
          <Route path="/create" element={<ScaffolderPage />}>            
            <ScaffolderFieldExtensions />
          </Route>
          <Route path="/api-docs" element={<ApiExplorerPage />} />
          <Route path="/docs" element={<TechDocsIndexPage />} />
          <Route path="/docs/:namespace/:kind/:name/*" element={<TechDocsReaderPage />} />
          <Route path="/catalog-import" element={<CatalogImportPage />} />
          <Route path="/azure-pipelines" element={<AzurePipelinesPage />} />
          <Route path="/grafana" element={<GrafanaPage />} />
          <Route path="/kubernetes" element={<KubernetesPage refreshIntervalMs={30000} />} />
          <Route path="/techdocs" element={<DocsRouter />} />
        </FlatRoutes>
      </AppRouter>
    </Root>
  </AppProvider>,
);
